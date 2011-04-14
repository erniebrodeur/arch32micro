arch32micro
===========
This repo is for any custom scripts needed to boot Arch properly inside Amazon EC2.

At this time, each script serves a specific, unique purpose.

ec2-inject-keys
-------------
The only thing this script does right now is grab the key that was made with the instance and inject
it into /root/.ssh/authorized_keys.

TODO:
-----
* Support multiple keys (if Ec2 does).

ec2-user-data:
--------------
I have not decided exactly how I want this script to work, but the idea is for it to inject the user data field.

I am honestly unsure how this entire mechanisim works at this time.

ec2d
----
This is a script designed for /etc/rc.d to be called on each boot.

* It will check for the presence of a firstrun file, so that only events happen once per instance.
* It will respond to userdata to push the userdata script (whatever that is)
* It will respond to start for tasks to be called each time (if needed).
* It will respond to clean, which will purge any key's injected (safely, if you customize it will not).

PKGBUILD
--------
How/where ever the files finally live, a PKGBUILD is only suiting since this is an ArchLinux designed system.


 Feel free to use the wiki or the issue system built into github, or send me a message.