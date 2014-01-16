class python::install {

  # TODO : it would be good to have a way to install python 2.7 on CentOS 6.4 at some point
  $package_ensure = $python::version ? {
    'system' => 'present',
    default  => $python::version,
  }

  $pythondev = $::operatingsystem ? {
    /(?i:RedHat|CentOS|Fedora)/ => "python-devel",
    /(?i:Debian|Ubuntu)/        => "python-dev"
  }

  package { 'python':
    ensure => $package_ensure,
  }

  $dev_ensure = $python::dev ? {
    true    => present,
    default => absent,
  }

  $pip_ensure = $python::pip_version ? {
    present => "pip -U",
    default => "pip==${python::pip_version} -U"
  }

  $setuptools_ensure = $python::setuptools_version ? {
    present => "setuptools -U",
    default => "setuptools==${python::setuptools_version} -U"
  }

  package { $pythondev: ensure => $dev_ensure }
  #package { 'python-pip': ensure => $pip_ensure }

  $download_command = $::operatingsystem ? {
    /(?i:RedHat|CentOS|Fedora)/ => 'curl -o',
    /(?i:Debian|Ubuntu)/        => 'wget -O'
  }

  # bootstrap setuptools if it doesn't exist
  exec { 'download ez_setup':
    command => "${download_command} /tmp/ez_setup.py https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py",
    unless  => 'test -f /usr/bin/easy_install && (/usr/bin/easy_install --version | grep setuptools)',
    notify  => Exec['bootstrap setuptools'],
  }
  ->
  exec { 'bootstrap setuptools':
    command     => 'python /tmp/ez_setup.py',
    refreshonly => true,
  }

  if $python::pip {
    exec { 'bootstrap pip':
      command   => 'easy_install pip',
      creates   => '/usr/bin/pip',
      unless    => 'test -f /usr/bin/pip -o -f /usr/bin/pip-python',
      subscribe => Exec['bootstrap setuptools'],
    }

    # NOTE : This will probably always fail if pip_version is not explicitly set...
    exec { 'pypi-pip':
      command => "pip install ${pip_ensure}",
      unless  => "test ${python::pip_version} == `pip show pip | grep Version | cut -c 10-`"
    }
    exec { 'pypi-setuptools':
      command => "pip install ${setuptools_ensure}",
      unless  => "test ${python::setuptools_version} == `pip show setuptools | grep Version | cut -c 10-`"
    }

    case $operatingsystem {
      'CentOS': {
        Exec['bootstrap pip']
        ->
        file { 'pip-python fix':
          path   => '/usr/bin/pip-python',
          ensure => link,
          target => '/usr/bin/pip',
        }
        ->
        Exec['pypi-setuptools']
        ->
        Exec['pypi-pip']
      }
      default: {
        Exec['bootstrap pip']
        ->
        Exec['pypi-setuptools']
        ->
        Exec['pypi-pip']
      }
    }
  }

  # TODO : need to clean this up, it's too much of a hack right now
  # TODO : need to extend pip install with easy_install to other platforms

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
