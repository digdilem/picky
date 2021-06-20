# picky
A self-hosted text file webreader made with Perl, Bootstrap 3 and Plack

![image](https://user-images.githubusercontent.com/4052275/122682057-4500c780-d1ef-11eb-9cd0-79d5ddeb1091.png)

I keep some stories in .txt format in a directory. I wanted a simple way to be able to pick a random one and start reading. This is the result.

# Features:
- Simple reading and nice display of text files (no markup or html processing done)
- Ability to search based on filename (no content search)
- Can edit files in-situ
- Can delete files (Note: There's no confirmation and it will need write permission over the files)
- Allows you to vote up and down a file by 10 points out of a 100, or give a particularly great file a "Top score" of 100
- Allows you to pick "great" files, those whose score is over 90
- Runs as a systemd service on a configurable port. systemd unit file supplied
 
# Installation:
Requires linux or similar. Bootstrap is loaded via cdn, so no installation of that is required.
1. Install [Plack](https://metacpan.org/pod/Plack), using either your distro's package manager or cpanm. Specifically these modules:
```
Plack::Request
Plack::Builder
```
Picky also uses `DBI` and `File::Slurp` but these are both in Perl Core and should be available for any recent version of Perl.
2. Copy `picky.psgi` file somewhere suitable, such as /var/www/html
3. Edit picky.service so it points to that file and install where your distro puts Systemd service files. 
Eg, in Debian and Centos, this is `/etc/systemd/system/`
4. Enable and start the service: 
```
systemctl daemon-reload
systemctl start picky
systemctl enable picky
```
5. Create a database in mysql with the contents of the `picky.sql` file and a user that can read it (Username and password are saved in `picky.psgi`)
6. All going well, point your webbrowser at that machine, port 5001 (or whatever you specified in picky.service)

