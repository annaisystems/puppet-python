class python::install {

  $python = $python::version ? {
    'system' => 'python',
    default  => "python${python::version}",
  }

  $pythondev = $::operatingsystem ? {
    /(?i:RedHat|CentOS|Fedora)/ => "${python}-devel",
    /(?i:Debian|Ubuntu)/        => "${python}-dev"
  }

  package { $python: ensure => present }

  $dev_ensure = $python::dev ? {
    true    => present,
    default => absent,
  }

  $pip_ensure = $python::pip ? {
    true    => present,
    default => absent,
  }

  package { $pythondev: ensure => $dev_ensure }
  #package { 'python-pip': ensure => $pip_ensure }

  # TODO : need to clean this up, it's too much of a hack right now
  # TODO : need to extend pip install with easy_install to other platforms
  if ($pip_ensure) {
    case $operatingsystem {
      'CentOS': {
        if !defined(Package['python-setuptools']) {
          package { 'python-setuptools':
            ensure => present,
          }
        }

        Package['python-setuptools']
        ->
        package { 'python-pip':
          ensure => absent,
        }
        ->
        # TODO : this should ideally be checking the pip version
        exec { 'install latest pip':
          command     => 'easy_install pip',
          creates     => '/usr/bin/pip',
        }
        ->
        exec { 'pip-python alternative':
          command     => 'alternatives --install /usr/bin/pip-python pip-python /usr/bin/pip 1',
          subscribe   => Exec['install latest pip'],
          unless      => 'which pip-python'
        }
      }
      default: {
        package { 'python-pip': ensure => $pip_ensure }
      }
    }
  }

  $venv_ensure = $python::virtualenv ? {
    true    => present,
    default => absent,
  }

  package { 'python-virtualenv': ensure => $venv_ensure }

  $gunicorn_ensure = $python::gunicorn ? {
    true    => present,
    default => absent,
  }

  package { 'gunicorn': ensure => $gunicorn_ensure }

}
