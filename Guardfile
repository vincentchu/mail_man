
postercloud_opts = {
  :hostname    => "goliath.posterdev.com",
  :user        => "capuser",
  :sftp_opts   => {},
  :remote      => "/home/capuser/git/mail_man",
  :debug       => true, 
  :growl       => true,
  :growl_image => File.join(File.dirname(__FILE__), "public/images/posterous_35.png") 
}

group :devcloud do
  puts ">>> Starting :devcloud group"
  
  guard 'flopbox', postercloud_opts do
    watch(/^[^\.].*/)
  end  
end

