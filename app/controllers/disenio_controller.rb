#!/usr/bin/env ruby
class DisenioController < ApplicationController
  #before_action :require_empresa, only: [:index, :show]
  def index
    @disenios = Disenio.all
  end

  def show
    @disenio = Disenio.find(params[:id_disenio])
    @proyecto = Proyecto.find(params[:id_proyecto])
    @empresa = Empresa.find(@proyecto.empresa_id)
  end

  def new
    @disenio = Disenio.new
    @proyecto = Proyecto.find(params[:id_proyecto])
    @empresa = Empresa.find(@proyecto.empresa_id)
  end

  def create
    @disenio = Disenio.new(disenio_params2)
    @proyecto = Proyecto.find(@disenio.proyecto_id)
    @empresa = Empresa.find(@proyecto.empresa_id)
    if(@disenio.save)
      procesarImagen(@disenio)
      redirect_to "/empresas/#{@empresa.nombre_empresa}/#{@proyecto.id}"
    else
      render 'new'
    end
  end

  def edit
    @disenio = Disenio.find(params[:id_disenio])
    @proyecto = Proyecto.find(@disenio.proyecto_id)
    @empresa = Empresa.find(@proyecto.empresa_id)
  end

  def update
    @disenio = Disenio.find(params[:id])
    @proyecto = Proyecto.find(@disenio.proyecto_id)
    @empresa = Empresa.find(@proyecto.empresa_id)
    if @disenio.update_attributes(disenio_params)
      redirect_to "/empresas/#{@empresa.nombre_empresa}/#{@proyecto.id}"
    else
      render 'edit'
    end
  end

  def destroy
    @disenio = Disenio.find(params[:id_disenio])
    @proyecto = Proyecto.find(@disenio.proyecto_id)
    @empresa = Empresa.find(@proyecto.empresa_id)
    Disenio.delete(@disenio)
    redirect_to "/empresas/#{@empresa.nombre_empresa}/#{@proyecto.id}"
  end

  def self.prueba
    @disenios = Disenio.where(estado: "En proceso")
    @disenios.each do |d|
      procesarImagen(d)
    end
    print("Llego hasta aqui")
    SenderMail.prueba.deliver_now
  end

  private
    def disenio_params
      params.require(:disenio).permit(:nombre_diseniador, :apellido_diseniador, :estado, :precio_solicitado, :email_diseniador)
    end
  private
    def disenio_params2
      params.require(:disenio).permit(:nombre_diseniador, :apellido_diseniador, :estado, :precio_solicitado, :email_diseniador, :proyecto_id, :picture)
    end
  private
    def procesarImagen(disenio)
      Thread.new do
        @disenio = disenio
        print("Entro")
        direccion = "#{@disenio.picture.path}"
        print("Paso Direccion con correo #{@disenio.email_diseniador}")
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

        # the base image
        img = Magick::Image.read(direccion)[0].strip!
        print("[DESARROLLADOR] Lectura de la imagen\n")
        ximg = img.resize_to_fit(width, height)
        print("[DESARROLLADOR] Resize\n")
        # label the image with the method name

        print("[DESARROLLADOR] #{@disenio.created_at}")
        mensaje = "#{@disenio.nombre_diseniador} ::: #{@disenio.created_at}"

        lbl = Magick::Image.new(width, height)
        gc.annotate(ximg, 0, 0, 0, 0, mensaje)

        # save the new image to disk
        new_fname = "#{direccion}-[PROCESADA].png"
        ximg.write((new_fname))
        print("PROCESANDO #{direccion}\n")
        @disenio.estado = "Disponible"
        @disenio.save
        SenderMail.enviar(@disenio).deliver_now
      end
    end
end
