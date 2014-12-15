HbxSoa::App.controllers :files do
  post :store, :map => "/files" do
    chunk_size = 21000
    bod = request.body
    sf = StreamFile.new(bod)
    sf.store!
    sf.filename
  end

  get :retrieve, :map => "/files", :with => :id do
    content_type "application/octet-stream"
    sf = StreamFile.find(params[:id])
    if sf
      stream do |out|
        sf.with_chunks do |data|
          out << data
        end
        sf.remove!
      end
    else
      error 404
    end
  end

  # get :index, :map => '/foo/bar' do
  #   session[:foo] = 'bar'
  #   render 'index'
  # end

  # get :sample, :map => '/sample/url', :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   'Maps to url '/foo/#{params[:id]}''
  # end

  # get '/example' do
  #   'Hello world!'
  # end


end
