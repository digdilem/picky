# picky
A self-hosted text file webreader made with Perl, Bootstrap 3 and Plack

![image](https://user-images.githubusercontent.com/4052275/122682057-4500c780-d1ef-11eb-9cd0-79d5ddeb1091.png)

I keep stories in .txt format in a directory. I wanted a simple way to be able to pick a random one and start reading. This is the result.

# Features:
- Simple reading and nice display of text files (no markup or html processing done). 
- Ability to search based on filename
- Can edit files in-situ. 
- Can delete files (Note: There's no confirmation and it will need write permission over the files)
- Allows you to vote up and down a file by 10 points out of a 100, or give a particularly great file a "Top score" of 100.
- Allows you to pick "great" files, those whose score is over 90.
- Runs as a systemd service on a configurable port. systemd unit file supplied
 


