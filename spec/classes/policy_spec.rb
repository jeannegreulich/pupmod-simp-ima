require 'spec_helper'

describe 'ima::policy' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      if os_facts[:operatingsystemmajrelease].to_s == '6'
        let(:facts) do
          os_facts.merge(init_systems: ['sysv'])
        end
      else
        let(:facts) do
          os_facts.merge(init_systems: ['systemd'])
        end
      end

      let(:default_sample) {
        File.read(File.expand_path('spec/files/default_ima_policy.conf'))
      }

      context 'with default params' do
        context 'nothing else set' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('ima::policy') }
          it { is_expected.to contain_class('ima') }
          it { is_expected.to create_file('/etc/ima').with_ensure('directory') }
          it { is_expected.to create_file('/etc/ima/policy.conf') \
            .with_content(IO.read('spec/files/default_ima_policy.conf')) }
          if os_facts[:operatingsystemmajrelease].to_s == '6'
            it { is_expected.to create_file('/etc/init.d/import_ima_rules').with({
              :ensure => 'file'
            }) }
            it { is_expected.to create_service('import_ima_rules').with({
              :ensure  => 'stopped',
              :enable  => true,
            }) }
          else
            it { is_expected.to create_exec('systemd_load_policy') }
          end

          context 'with ima enabled' do
            if os_facts[:operatingsystemmajrelease].to_s == '6'
              let(:facts) do
                os_facts.merge({
                  :init_systems => ['sysv'],
                  :cmdline => {
                    :ima => 'on'
                  }
                })
              end
            else
              let(:facts) do
                os_facts.merge({
                  :init_systems => ['systemd'],
                  :cmdline => {
                    :ima => 'on'
                  }
                })
              end
            end

            it { is_expected.to create_exec('load_ima_policy') \
              .with_command('cat /etc/ima/policy.conf > /sys/kernel/security/ima/policy') }
          end
        end

        context 'with an selinux policy disabled' do
          let(:params) {{
            dont_watch_lastlog_t: false,
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/ima/policy.conf') \
            .with_content(IO.read('spec/files/selinux_ima_policy.conf')) }
        end

        context 'with an fsmagic disabled' do
          let(:params) {{
            dont_watch_binfmtfs: false,
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/ima/policy.conf') \
            .with_content(IO.read('spec/files/fsmagic_ima_policy.conf')) }
        end

        context 'with custom selinux contexts' do
          let(:params) {{
            dont_watch_list: [ 'user_home_t', 'locale_t' ],
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/ima/policy.conf') \
            .with_content(IO.read('spec/files/custom_ima_policy.conf')) }
        end

        context 'with the other ima params set' do
          let(:params) {{
            measure_root_read_files: true,
            measure_file_mmap: true,
            measure_bprm_check: true,
            measure_module_check: true,
            appraise_fowner: true,
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/ima/policy.conf') \
            .with_content(IO.read('spec/files/other_ima_policy.conf').chomp) }
        end
      end

      context 'with manage = false' do
        let(:params) {{
          manage: false,
        }}
        it { is_expected.to create_class('ima::policy') }
        if os_facts[:operatingsystemmajrelease].to_s == '6'
          it { is_expected.to create_file('/etc/init.d/import_ima_rules').with_ensure('absent') }
          it { is_expected.to create_service('import_ima_rules').with({
            :ensure  => 'stopped',
            :enable  => false,
          }) }
        else
          it { is_expected.to create_file('/usr/lib/systemd/system/import_ima_rules.service').with_ensure('absent') }
          it { is_expected.to create_service('import_ima_rules.service').with.with({
            :ensure  => 'stopped',
            :enable  => false,
          }) }
        end
      end

    end
  end
end
