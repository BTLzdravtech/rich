module Rich
  class FilesController < ApplicationController
    skip_before_action :verify_authenticity_token, if: lambda{ params[:type] == 'ckeditor_drop' }

    before_action :authenticate_rich_user
    before_action :set_rich_file, only: [:show, :destroy]

    layout "rich/application"

    def index
      @type = params[:type]

      if(@type == "image")
        @items = RichFile.images.order("created_at DESC").where(:owner_type => params[:scope_type], :owner_id => params[:scope_id]).page params[:page]
      else
        @items = RichFile.files.order("created_at DESC").where(:owner_type => params[:scope_type],  :owner_id => params[:scope_id]).page params[:page]
      end

      # stub for new file
      @rich_asset = RichFile.new

      respond_to do |format|
        format.html
        format.js
      end

    end

    def show
      # show is used to retrieve single files through XHR requests after a file has been uploaded

      if(params[:id])
        # list all files
        @file = @rich_file
        render :layout => false
      else
        render :text => "File not found"
      end

    end

    def create

      @file = RichFile.new
      @file.simplified_type = params[:simplified_type]

      if(params[:scoped] == 'true')
        @file.owner_type = params[:scope_type]
        @file.owner_id = params[:scope_id].to_i
      end

      # use the file from Rack Raw Upload
      file_params = if params[:type] == 'ckeditor_drop'
                      params[:upload]
                    else
                      params[:file] || params[:qqfile]
                    end
      if(file_params)
        file_params.content_type = Mime::Type.lookup_by_extension(file_params.original_filename.split('.').last.to_sym)
        @file.rich_file = file_params
      end

      if @file.save!
        response = if params[:type] == 'ckeditor_drop'
                     { :uploaded => 1, :fileName => file_params.original_filename, :url => @file.rich_file.url }
                   else
                     { :success => true, :rich_id => @file.id }
                   end
      else
        response = if params[:type] == 'ckeditor_drop'
                     { :uploaded => 0, :error => { :message => "Could not upload your file:\n- "+@file.errors.to_a[-1].to_s } }
                   else
                     { :success => false,
                       :error => "Could not upload your file:\n- "+@file.errors.to_a[-1].to_s,
                       :params => params.inspect }
                   end
      end

      render :json => response, :content_type => "text/html"
    end

    def destroy
      if(params[:id])
        @rich_file.destroy
        @fileid = params[:id]
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_rich_file
        @rich_file = RichFile.find(params[:id])
      end
  end
end
