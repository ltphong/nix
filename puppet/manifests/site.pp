# Global define
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

# nginx
class nginx {
	package { 'nginx' :
		ensure => installed
	}
	service { 'nginx':
		ensure	=> true,
		enable	=> true,
		require	=> Package['nginx']
	}
}

# Adding extra repos:
#	"dotdeb.org"
#	"nginx.org"
class extra_repo {
	file { '/tmp/dotdeb.gpg':
		ensure 	=> present,
		mode 	=> 644,
		owner 	=> root,
		group	=> root,
		source  => 'puppet:///files/dotdeb.gpg',
	}
	file { '/etc/apt/sources.list':
                ensure  => present,
                mode    => 644,
                owner   => root,
                group   => root,
                source  => 'puppet:///files/sources.list',
        }
	exec { 'apt-key':
                command => "apt-key add /tmp/dotdeb.gpg && \
			    apt-get update && \
			    rm /tmp/dotdeb.gpg",
        }
}

# Adjust server settings
class settings {
	package { 'ssmtp'       : ensure        => installed }
	package { 'bsd-mailx'   : ensure        => installed }
	package { 'cron-apt'	: ensure        => installed }
	package { 'fail2ban'	: ensure        => installed }
	package { 'logwatch     : ensure        => installed }
	package { 'lsb-release'	: ensure        => installed }
	file { '/etc/resolv.conf':
                ensure  => present,
                mode    => 644,
                owner   => root,
                group   => root,
                source  => 'puppet:///files/resolv.conf'
        }
	file { '/etc/bash.bashrc':
                ensure  => present,
                mode    => 644,
                owner   => root,
                group   => root,
                source  => 'puppet:///files/bash.bashrc'
        }
	file { '/etc/ssmtp/ssmtp.conf':
                ensure  => present,
                mode    => 644,
                owner   => root,
                group   => root,
                source  => 'puppet:///files/ssmtp.conf',
        }
	exec { 'rm':
                command => "rm /usr/sbin/sendmail && \
                            ln -s /usr/sbin/ssmtp /usr/sbin/sendmail",
        }
}

# Hardening/Securing server
class hardening {
	file { '/etc/sysctl.conf':
                ensure  => present,
                mode    => 644,
                owner   => root,
                group   => root,
                source  => 'puppet:///files/sysctl.conf'
	}
	exec { 'sysctl'	: command	=> 'sysctl -p', }
	exec { 'sed':
                command => "sed -i 's/id:2:initdefault:/id:3:initdefault:/g' /etc/inittab && \
			    sed -i 's/# set const/set const/g' /etc/nanorc && \
			    sed -i 's/38400 tty1/--noclear 38400 tty1/g' /etc/inittab && \
			    sed -i 's/#GRUB_DISABLE_LINUX_UUID/GRUB_DISABLE_LINUX_UUID/g' /etc/default/grub && \
			    echo net.ipv6.conf.all.disable_ipv6=1 | tee /etc/sysctl.d/disableipv6.conf && \
			    echo 'alias net-pf-10 off' | tee /etc/modprobe.d/aliases.conf && \
			    echo 'alias ipv6 off' >> /etc/modprobe.d/aliases.conf && \
			    sed -i 's/::1/#::1/g' /etc/hosts && \
			    sed -i 's/ff02/#ff02/g' /etc/hosts && \
			    echo 'AddressFamily inet' >> /etc/ssh/sshd_config && \
			    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
			    sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config && \
			    /etc/init.d/ssh restart && \
			    usermod -a -G adm ltphong && \
			    usermod -a -G sudo ltphong && \
			    dpkg-statoverride --update --add root adm 4750 /bin/su && \
			",
        }
}

class iptables {
	package { 'iptables':
		ensure	=> installed
	}
	service { 'iptables':
		enable	=> true,
		ensure	=> true,
		hasstatus => true,
	}
	file { '/etc/init.d/iptables':
                ensure  => present,
                mode    => 755,
                owner   => root,
                group   => root,
                source  => 'puppet:///files/iptables',
	}
}
node 'mail.abc.com' {
#	include extra_repo
#	include hardening
#	include iptables
	include ssmtp
}
