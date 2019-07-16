# OpenCEAS
## What's OpenCEAS?
OpenCEAS is an open-source LMS (Learning Management System) for higher education. It inherits the teaching/learning cycle support functions and the Teaching-Support User Interface from the original CEAS (the Web-Based Coordinated Education Activation System) first released in 2003.  
OpenCEAS is built using Ruby on Rails as the web application framework and is a totally re-written version of the CEAS. OpenCEAS incorporates JQuery, HTML5, and CSS3 to accommodate various modern web browsers and recent users' multi-device usage.
## Formation of a Teaching and Learning Cycle
OpenCEAS gives assistance to the formation of a tripartite teaching/learning cycle consisting of preparation, classroom, and review activities. The cycle being based on a Japanese teaching/learning model, OpenCEAS gives psychological affordance to both instructors and learners, thereby making them aware of the cycle.
## Teaching-Support User Interface
* Menus are provided in groups in accordance with the tripartite categories (i.e., before, in, after the class) with a focus on class implementation.
* Class materials and reports are offered/ submitted on a class-by-class basis.
* Students' performance during the course can be viewed at Student-Record-at-a-Glance and easily be used for final evaluation.
* No faculty training/orientation is needed to use the system.
## Special Features
* No content package is required for registration at the beginning of each course.
* It comes with sophisticated basic functions that help with the course management on a class-by-class basis.
* Teacher-Support User Interface (TS-UI) makes each operation easy and accessible for faculty users.
## License
OpenCEAS is released under the MIT License.

## Installation
OpenCEAS requires Ruby 2.4 or greater. (Ruby 2.5 can be used, but it is well tested with Ruby 2.4. A minimum version of 2.4.4 is recommended.) You need to install the Ruby libraries and packages that OpenCEAS needs.  
In addition, OpenCEAS uses Bundler to manage version dependencies of Ruby Gems. You can install Bundler using Ruby Gems. Once you have installed Bundler, please navigate to the OpenCEAS application root directory, where you will install all of the OpenCEAS components using Bundler. Just run the `bundle install` command for you easy installation.  
As for a DBMS software, use of MySQL or MariaDB is recommended, since both have been tested in our development. Note that other DBMS can be used as well because OpenCEAS uses the ActiveRecord library which supports many database adapters. You are also advised to create a database with UTF-8 encoding.  

### Installation procedures are as follows:  
Following the procedure below, you will create the application root directory named `openceas` in an appropriate directory such as ~/workspace, where all the OpenCEAS resource files are deployed.  

1. Get the openceas clone from the GitHub.  
```
      $git clone git@github.com:fuyuki-acad/openceas.git openceas  
      $cd openceas
```
2. Install the specified RubyGems.  
Since the required gems are listed in the Gemfile, just run the next command to install all dependencies in the application root directory.  
```
      $bundle install
```
3. Create the configuration files referring to `.example` files in the config directory.  
As OpenCEAS depends on a few configuration files the basic examples of which are shipped with, you should first set up the configuration files before setting up all the tables in your database.  

4. Execute the initial table creation processing in the database with Bundler.
```
      $ bundle exec rake db:migrate
```
5. Load the initial data in the database.  
Once your database is configured, you need to actually fill the tables with initial data. You can do this by running a rake task at the application root directory.  
After installation, refer to `db/seeds.rb` for authentication information of the initial system administrator.  
```
      $ bundle exec rake db:seed
```
6. Generate the assets using appropriate JavaScript runtime.  
You will also need a JavaScript runtime to translate CoffeeScript code to JavaScript and a few other things.
```
      $ bundle exec rake assets:precompile
```
7. Create the Web API documents, if necessary. (Optional)
```
      $ bundle exec yard -o public/doc
```
That completes the necessary procedures for installation.  
## Configuration of your web application environment  
You are now going to need to set up the webserver. You will need to install and configure a webserver software (Apache, Nginx and the like). Depending on your preference, you can choose whatever app server software you like that runs the rails web application (Passenger, Unicorn, Puma or others).  
