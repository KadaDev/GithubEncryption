require "rubygems"
require "bundler/setup"

require "octokit"
require "json"
require 'fileutils'

FileUtils::mkdir_p 'tmpkeys'

def getOauthToken settings
    puts('enter username: ')
    settings[:username] = gets.chomp
    puts('enter password: ')
    pw = gets.chomp
    client = Octokit::Client.new :login => settings[:username], :password => pw

    begin
        settings[:oauth] = client.create_authorization(:scopes => ["user"], :note => "testtoken")
    rescue Octokit::OneTimePasswordRequired
        puts 'One Time Password needed, enter now:'
        otp = gets.chomp
        settings[:oauth] = client.create_authorization(:scopes => ["repo"], :note => "testtoken", :headers => {"X-GitHub-OTP" => otp}).token
        File.open($settingsfile, 'w') { |file| file.write(JSON.generate(settings))}
    end
end

$settingsfile = 'settings.json'
settings = {}
if File.exists? $settingsfile
    file = File.read($settingsfile)
    settings = JSON.parse(file, {symbolize_names: true})
end
if (!settings[:oauth])
    getOauthToken settings
end

Octokit.configure do |c|
    c.access_token = settings[:oauth]
end

user = Octokit.user
user.login
puts user.name

repository = %x( git config --get remote.origin.url ).chomp
repo_name = repository.split('/')[-2,2].join('/')
puts "Found #{repo_name}, is this correct? (Y/n)"
if (!(gets.chomp =~ /^(y|)$/i))
    puts "Enter repo name as 'Owner/Repo'"
    repo_name = gets.chomp
end

keys = []
collabs = Octokit.collabs repo_name
collabs.each do |user|
    Octokit.user_keys(user.login).each do | key|
        keys.push(key)
    end

end

keynames = []
keys.each do |key|
    # Need a pem file, so we convert it
    keyname = key.id
    keylocation = "tmpkeys/#{keyname}.pub"
    File.open(keylocation, 'w') { |file| file.write(key.key)}
    puts "Converting public key to a PEM PKCS8 public key"
    %x(ssh-keygen -f #{keylocation} -e -m PKCS8 > tmpkeys/#{keyname}.pem)

    if ($? != 0)
        puts 'Someting went wrong!'
        break
    else
        keynames.push("tmpkeys/#{keyname}.pem")
    end
end
files = File.readlines('files.conf')
files.each do |filename|
    filename = filename.chomp
    encrypted = ""
    keynames.each do | keyname|
        cmdline = "openssl rsautl -encrypt -in #{filename} -pubin -inkey #{keyname}"
        encrypted += %x(#{cmdline})
        if ($? != 0)
            puts 'Someting went wrong!'
            break
        end
    end

    File.open(filename, 'w') { |file| file.write(encrypted)}
end
