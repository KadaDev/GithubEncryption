tmpfile = 'tmpfile.enc'
files = File.readlines('files.conf')
files.each do |filename|
    filename = filename.chomp
    file = File.open(filename, "r")
    while (line = file.read(256))
        File.open(tmpfile, 'w') {|fil| fil.write(line)}
        file_content = %x(openssl rsautl -decrypt -inkey ~/.ssh/id2_rsa -in #{tmpfile} 2>&1)
        if ($? == 0)
            puts file_content
            File.open(filename, 'w') do |file|
                file.write(file_content)
            end
        end
    end
end
