class Interpret::TranslationsController < ApplicationController
  def index
    @translations = Interpret::Translation.locale(I18n.locale).all

    respond_to do |format|
      format.html
      format.xml  { render :xml => @translations }
    end
  end

  def edit
    @translation = Interpret::Translation.find(params[:id])
  end

  def update
    @translation = Interpret::Translation.find(params[:id])
    old_value = @translation.value

    respond_to do |format|
      if @translation.update_attributes(params[:interpret_translation])
        Interpret.backend.reload!
        # Hook here
        msg = defined?(:current_user) ? "By [#{current_user}]. " : ""
        msg << "Locale: [#{@translation.locale}], key: [#{@translation.key}]. The translation has been changed from [#{old_value}] to [#{@translation.value}]"
        Interpret.logger.info msg

        format.html { redirect_to(translations_url)}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def fetch
    require 'ya2yaml'

    translations = Interpret::Translation.locale(I18n.locale).all
    hash = Interpret::Translation.as_hash(translations)
    text = hash.ya2yaml

    send_data text[5..text.length], :filename => "#{I18n.locale}.yml"
  end

  def upload
    unless params.has_key? :file
      flash[:alert] = "Tienes que subir un archivo"
      redirect_to translations_url
      return
    end

    file = params[:file]
    if file.content_type && file.content_type.match(/^text\/.*/).nil?
      flash[:alert] = "Tienes que subir un archivo en formato de texto"
      redirect_to translations_url
      return
    end

    begin
      hash = YAML.load file
      unless hash.keys.count == 1
        flash[:alert] = "El archivo YAML debe tener una sola clave inicial con el nombre del idioma"
        redirect_to translations_url
        return
      end

      unless hash.keys.first.to_s == I18n.locale.to_s
        flash[:alert] = "Estas subiendo un archivo de traducciones en un idioma que no coincide con el actual"
        redirect_to translations_url
        return
      end

      changes = Interpret::Translation.update_from_hash(I18n.locale, hash.values[0])
      Interpret.backend.reload!

      flash[:notice] = "#{changes} Traduccions actualitzades correctament"
    rescue ArgumentError => e
      flash[:alert] = "Formato de archivo no valido"
    end

    redirect_to translations_url
  end
end
