HbxSoa::App.controllers :sequences do
  get :retrieve, :map => "/sequences", :with => :id do
    the_count = params[:count].blank? ? 1 : params[:count].to_i
    content_type "application/json"
    result = ExchangeSequence.generate_identifiers(params[:id], the_count)
    if result.nil?
      status 404
      body ""
    else
      status 200
      body JSON.dump(result.last)
    end
  end
end
