require 'spec_helper'

describe 'cipherguar_api service' do
  before(:all) do
    @mysql_image =
      if ENV['GITLAB_CI']
        Docker::Image.create(
          'fromImage' => 'registry.gitlab.com/khulnasoft/cipherguard-ci-docker-images/mariadb-10.3:latest'
        )
      else
        Docker::Image.create('fromImage' => 'mariadb:latest')
      end

    @mysql = Docker::Container.create(
      'Env' => [
        'MARIADB_ROOT_PASSWORD=test',
        'MARIADB_DATABASE=cipherguar',
        'MARIADB_USER=cipherguar',
        'MARIADB_PASSWORD=±!@#$%^&*()_+=-}{|:;<>?'
      ],
      'Healthcheck' => {
        "Test": [
          'CMD-SHELL',
          'mysqladmin ping --silent'
        ]
      },
      'Image' => @mysql_image.id
    )

    @mysql.start

    sleep 1 while @mysql.json['State']['Health']['Status'] != 'healthy'

    if ENV['GITLAB_CI']
      Docker.authenticate!(
        'username' => ENV['CI_REGISTRY_USER'].to_s,
        'password' => ENV['CI_REGISTRY_PASSWORD'].to_s,
        'serveraddress' => 'https://registry.gitlab.com/'
      )
      @image =
        if ENV['ROOTLESS'] == 'true'
          Docker::Image.create(
            'fromImage' => "#{ENV['CI_REGISTRY_IMAGE']}:#{ENV['CIPHERGURD_FLAVOUR']}-rootless-latest"
          )
        else
          Docker::Image.create(
            'fromImage' => "#{ENV['CI_REGISTRY_IMAGE']}:#{ENV['CIPHERGURD_FLAVOUR']}-root-latest"
          )
        end
    else
      @image = Docker::Image.build_from_dir(
        ROOT_DOCKERFILES,
        {
          'dockerfile' => $dockerfile,
          'buildargs' => JSON.generate($buildargs)
        }
      )
    end

    @container = Docker::Container.create(
      'Env' => [
        "DATASOURCES_DEFAULT_HOST=#{@mysql.json['NetworkSettings']['IPAddress']}",
        'DATASOURCES_DEFAULT_PASSWORD=±!@#$%^&*()_+=-}{|:;<>?',
        'DATASOURCES_DEFAULT_USERNAME=cipherguar',
        'DATASOURCES_DEFAULT_DATABASE=cipherguar',
        'CIPHERGURD_SSL_FORCE=true'
      ],
      'Image' => @image.id,
      'Binds' => $binds
    )

    @container.start
    @container.logs(stdout: true)

    set :docker_container, @container.id
    sleep 17
  end

  after(:all) do
    @mysql.kill
    @container.kill
  end

  let(:cipherguar_host)     { @container.json['NetworkSettings']['IPAddress'] }
  let(:uri)               { '/healthcheck/status.json' }
  let(:curl)              { "curl -sk -o /dev/null -w '%{http_code}' -H 'Host: cipherguar.local' https://#{cipherguar_host}:#{$https_port}/#{uri}" }

  let(:rootless_env_setup) do
    # The sed command needs to create a temporary file on the same directory as the destination file (/etc/cron.d).
    # So when running this tests on the rootless image we have to move the crontab file to tmp, execute the sed on it
    # and copy it back to /etc/cron.d.
    @container.exec(['cp', "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server", '/tmp/cipherguar-cron'])
    @container.exec(['cp', "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server", '/tmp/cipherguar-cron-temporary'])
    @container.exec(
      [
        'sed',
        '-i',
        "s\,$CIPHERGURD_BASE_DIR/bin/cron.*\,/bin/bash -c \"\\.\\ /etc/environment\\ \\&\\&\\ env > /tmp/cron-test\"\,",
        '/tmp/cipherguar-cron-temporary'
      ]
    )
    @container.exec(['cp', '/tmp/cipherguar-cron-temporary', "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server"])
    # force reload supercronic cron file
    @container.exec(%w[supervisorctl restart cron])

    # wait for cron
    sleep 61
  end

  let(:cron_env_teardown) do
    @container.exec(['mv', '/tmp/cipherguar-cron', "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server"])
    @container.exec(['rm', '/tmp/cipherguar-cron-temporary'])
  end

  let(:root_env_setup) do
    @container.exec(['cp', "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server", '/tmp/cipherguar-cron'])
    @container.exec(
      [
        'sed',
        '-i',
        "s\,\\.\\ /etc/environment\\ \\&\\&\\ $CIPHERGURD_BASE_DIR/bin/cron\,\\.\\ /etc/environment\\ \\&\\&\\ env > /tmp/cron-test\,",
        "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server"
      ]
    )
    @container.exec(
      [
        'cp',
        '/tmp/cipherguar-cron-temporary', "/etc/cron.d/cipherguar-#{ENV['CIPHERGURD_FLAVOUR']}-server"
      ]
    )

    # wait for cron
    sleep 61
  end

  describe 'php service' do
    it 'is running supervised' do
      expect(service('php-fpm')).to be_running.under('supervisor')
    end
  end

  describe 'web service' do
    it 'is running supervised' do
      expect(service('nginx')).to be_running.under('supervisor')
    end

    it "is listening on port #{$http_port}" do
      expect(@container.json['Config']['ExposedPorts']).to have_key("#{$http_port}/tcp")
    end

    it "is listening on port #{$https_port}" do
      expect(@container.json['Config']['ExposedPorts']).to have_key("#{$https_port}/tcp")
    end
  end

  describe 'cipherguar status' do
    it 'returns 200' do
      expect(command(curl).stdout).to eq '200'
    end
  end

  describe 'can not access outside webroot' do
    let(:uri) { '/vendor/autoload.php' }
    it 'returns 404' do
      expect(command(curl).stdout).to eq '404'
    end
  end

  describe 'hide information' do
    let(:curl) { "curl -Isk -H 'Host: cipherguar.local' https://#{cipherguar_host}:#{$https_port}/" }
    it 'hides php version' do
      expect(command("#{curl} | grep 'X-Powered-By: PHP'").stdout).to be_empty
    end

    it 'hides nginx version' do
      expect(command("#{curl} | grep 'server:'").stdout.strip).to match(/^server:\s+nginx.*$/)
    end
  end

  describe 'cron service' do
    context 'cron process' do
      it 'is running supervised' do
        expect(service('cron')).to be_running.under('supervisor')
      end
    end

    # In order to be able to run this test on the rootess image
    # you will have to add the following to the Dockerfile (debian/Dockerfile.rootless)
    # && chown root:www-data /etc/cron.d/$CIPHERGURD_PKG \
    # && chmod 664 /etc/cron.d/$CIPHERGURD_PKG
    # And change the xit to it keyword on the test

    context 'cron rootless environment' do
      before { skip('Needs chown and chmod lines on the debian/Dockerfile.rootless to be able to run.') }
      before(:each) { rootless_env_setup }
      after(:each) { cron_env_teardown }

      it 'is contains the correct env' do
        expect(file('/tmp/cron-test').content).to match(/CIPHERGURD_GPG_SERVER_KEY_FINGERPRINT/)
      end
    end

    context 'cron root environment' do
      before { skip('Rootless environment does not need this test') if ENV['ROOTLESS'] == 'true' }
      before(:each) { root_env_setup }
      after(:each) { cron_env_teardown }

      it 'is contains the correct env' do
        expect(file('/tmp/cron-test').content).to match(/CIPHERGURD_GPG_SERVER_KEY_FINGERPRINT/)
      end
    end
  end
end
