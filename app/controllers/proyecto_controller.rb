class ProyectoController < ApplicationController
  def index
    @proyectos = Proyecto.all
  end

  def show
    @proyecto = Proyecto.find(params[:id])
    @empresa = Empresa.find(@proyecto.empresa_id)
    @disenios = @proyecto.disenios.where(estado: "Disponible").order(created_at: :desc).paginate(page: params[:page])
  end

  def new
    @proyecto = Proyecto.new
    @empresa = Empresa.find_by_nombre_empresa(params[:nombre_empresa])
  end

  def create
    @proyecto = Proyecto.new(proyecto_params2)
    @empresa = Empresa.find(current_empresa.id)
    if(@proyecto.save)
      redirect_to "/empresas/#{@empresa.nombre_empresa}"
    else
      render 'new'
    end
  end

  def edit
    @proyecto = Proyecto.find(params[:id])
  end

  def update
    @proyecto = Proyecto.find(params[:id])
    @empresa = Empresa.find(@proyecto.empresa_id)
    if @proyecto.update_attributes(proyecto_params)
      redirect_to "/empresas/#{@empresa.nombre_empresa}"
    else
      render 'edit'
    end
  end

  def destroy
    @proyecto = Proyecto.find(params[:id])
    @empresa = Empresa.find(@proyecto.empresa_id)
    Proyecto.delete(@proyecto)
    redirect_to "/empresas/#{@empresa.nombre_empresa}"
  end

  private
    def proyecto_params
      params.require(:proyecto).permit(:nombre, :descripcion, :valor_pagar)
    end
  private
    def proyecto_params2
      params.require(:proyecto).permit(:nombre, :descripcion, :valor_pagar, :empresa_id)
    end
end
