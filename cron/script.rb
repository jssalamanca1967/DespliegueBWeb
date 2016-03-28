#!/usr/bin/ruby
require "rubygems"
require "active_record"

ActiveRecord::Base.establish_connection ({
  :adapter => "mysql2",
  :host => "dbtest.c7adyf7ogphu.us-west-2.rds.amazonaws.com",
  :username => "cdsierra1199",
  :password => "HaroldCastro201601",
  :database => "designmatch",
  :port => "3306"})


connection = Fog::Storage.new({
  :provider                 => 'AWS',
  :aws_access_key_id        => ENV["AWSAccessKeyId"],
  :aws_secret_access_key    => ENV["AWSSecretKey"],
  :region		    => "us-west-2",
  :persistent		    => true
})
directorio=connection.directories.get(ENV["AWSBucket"])

@disenios = Disenio.where(estado: "En proceso")
@disenios.each do |d|
  print("---------REGISTRO---------")
  @disenio = d
  print("Entro")
  direccion = "#{@disenio.picture.path}"
  print("Paso Direccion con correo #{@disenio.email_diseniador}\n")
  width = 800
  height = 600

  # the Magick class used for annotations
  gc = Magick::Draw.new
  gc.font = 'helvetica'
  gc.pointsize = 12
  gc.font_weight = Magick::BoldWeight
  gc.gravity = Magick::SouthGravity
  gc.fill = 'white'
  gc.undercolor = 'black'

  s3_file = directorio.files.get(direccion)
  local_file = File.open("output","w+b")
  local_file.write(s3_file.body)
  local_file.close

  img_file = File.open("output", "r")
  # the base image
  img = Magick::Image.read(img_file)[0].strip!
  print("[DESARROLLADOR] Lectura de la imagen\n")
  ximg = img.resize_to_fit(width, height)
  print("[DESARROLLADOR] Resize\n")
  # label the image with the method name

  print("[DESARROLLADOR] #{@disenio.created_at}")
  mensaje = "#{@disenio.nombre_diseniador} ::: #{@disenio.created_at}"

  lbl = Magick::Image.new(width, height)
  gc.annotate(ximg, 0, 0, 0, 0, mensaje)

  ## save the new image to disk
  new_file_bucket = "#{direccion}-[PROCESADA].png"
  new_fname = "output.png"
  ximg.write((new_fname))
  img_file.close

  #local_file_md5 = Digest::MD5.file("output.png")
  s3_file_object = directorio.files.create(:key => new_file_bucket, :body => File.open("output.png"), :acl => "public-read")

  #newimg = directorio.files.new(new_file_bucket)
  #newimg.body = File.open("output.png")
  #newimg.acl = 'public-read'
  #newimg.save

  print("PROCESANDO #{direccion}\n")
  @disenio.estado = "Disponible"
  @disenio.save
  #SenderMail.enviar(@disenio).deliver_now

  ses = Aws::SES::Client.new(
      region: 'us-west-2',
      access_key_id: ENV['AWSAccessKeyId'],
      secret_access_key: ENV['AWSSecretKey']
  )

  resp2 = ses.send_email({
      source: "designmatch@outlook.com", # required
      destination: { # required
          to_addresses: ["#{@disenio.email_diseniador}", "js.salamanca1967@uniandes.edu.co"],
      },
      message: { # required
          subject: { # required
              data: "Tu disenio esta listo",
          },
          body: { # required
              text: {
                  data: "Leeeeel",
              },
              html: {
                  data: "<p>Tu disenio, creado el #{@disenio.created_at} para el proyecto ya esta disponible.</p>",
              },
          },
      },
  })

end
