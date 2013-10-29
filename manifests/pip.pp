# == Define: python::pip
#
# Installs and manages packages from pip.
#
# === Parameters
#
# [*ensure*]
#  present|absent. Default: present
#
# [*virtualenv*]
#  virtualenv to run pip in.
#
# [*url*]
#  URL to install from. Default: none
#
# [*owner*]
#  The owner of the virtualenv being manipulated. Default: root
#
# [*proxy*]
#  Proxy server to use for outbound connections. Default: none
#
# [*environment*]
#  Additional environment variables required to install the packages. Default: none
#
# [*version*]
#  Package version number.  This is used in lieu of specifying a version in the name.  Default: undef
#
# === Examples
#
# python::pip { 'flask':
#   virtualenv => '/var/www/project1',
#   proxy      => 'http://proxy.domain.com:3128',
# }
#
# === Authors
#
# Sergey Stankevich
# Fotis Gimian
#
define python::pip (
  $ensure          = present,
  $virtualenv      = 'system',
  $url             = false,
  $owner           = 'root',
  $proxy           = false,
  $egg             = false,
  $environment     = [],
  $install_args    = '',
  $uninstall_args  = '',
  $version         = undef,
) {

  # TODO : name with version and version paramter need to be mutually exclusive
  $python_module_name = $version ? {
    undef   => $name,
    default => "${name}==${version}",
  }

  # Parameter validation
  if ! $virtualenv {
    fail('python::pip: virtualenv parameter must not be empty')
  }

  if $virtualenv == 'system' and $owner != 'root' {
    fail('python::pip: root user must be used when virtualenv is system')
  }

  $cwd = $virtualenv ? {
    'system' => '/',
    default  => "${virtualenv}",
  }

  $pip_env = $virtualenv ? {
    'system' => 'pip',
    default  => "${virtualenv}/bin/pip",
  }

  $proxy_flag = $proxy ? {
    false    => '',
    default  => "--proxy=${proxy}",
  }

  $grep_regex = $python_module_name ? {
    /==/    => "^${python_module_name}\$",
    default => "^${python_module_name}==",
  }

  $egg_name = $egg ? {
    false   => $python_module_name,
    default => $egg
  }

  $source = $url ? {
    false   => $python_module_name,
    default => "${url}#egg=${egg_name}",
  }

  case $ensure {
    present: {
      exec { "pip_install_${python_module_name}":
        command     => "$pip_env --log ${cwd}/pip.log install $install_args ${proxy_flag} ${source}",
        unless      => "$pip_env freeze | grep -i -e ${grep_regex}",
        user        => $owner,
        environment => $environment,
      }
    }

    default: {
      exec { "pip_uninstall_${python_module_name}":
        command     => "echo y | $pip_env uninstall $uninstall_args ${proxy_flag} ${python_module_name}",
        onlyif      => "$pip_env freeze | grep -i -e ${grep_regex}",
        user        => $owner,
        environment => $environment,
      }
    }
  }

}
