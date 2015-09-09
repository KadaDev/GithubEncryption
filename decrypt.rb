
file = File.open("test.encrypted", "r")
while (line = file.read(256))
    File.open('test2.encrypted', 'w') {|fil| fil.write(line)}
    file_content = %x(openssl rsautl -decrypt -inkey ~/.ssh/id2_rsa -in test2.encrypted 2>&1)
    if ($? == 0)
        puts file_content
        break
    end
end
