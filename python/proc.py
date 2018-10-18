import subprocess

out = subprocess.check_output('sudo -u admin crontab -l', shell=True)

# Both above and below achieve similar results

import pexpect
passwd = "mypass"
child = pexpect.spawn('su myuser -c "crontab -l"')
child.expect('Password:')
child.sendline(passwd)
child.expect(pexpect.EOF)

print child.before
