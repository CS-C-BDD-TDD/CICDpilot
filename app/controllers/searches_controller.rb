class SearchesController < ApplicationController
  
  def index
    if params[:q].blank?
      render json: {errors: ["You must specify a search parameter 'q'"]}, status: 400
      return
    end

    options = {
      column: params[:column],
      direction: params[:direction],
      ebt: params[:ebt],
      iet: params[:iet],
      indicator_type: params[:indicator_type],
      limit: (params[:limit] || params[:amount] || Sunspot.config.pagination.default_per_page),
      offset: (params[:offset] || 0)
    }

    search = Search.indicator_search(params[:q], options)
    @total_indicators_count = search.total
    @indicators = search.results
    @metadata = Metadata.new
    @metadata.total_count = search.total

    search = Search.address_search(params[:q], options)
    @weather_map_addresses = search.results
    @weather_map_addresses.delete_if { |w| w.combined_score==nil }
    @total_weather_map_addresses_count = @weather_map_addresses.count

    search = Search.domain_search(params[:q], options)
    @weather_map_domains = search.results
    @weather_map_domains.delete_if { |w| w.combined_score==nil }
    @total_weather_map_domains_count = @weather_map_domains.count
    # can't pre-load both weather map data and addresses
    respond_to do |format|
      format.any(:html,:json) do
        render "searches/index.json.rabl", locals: {associations: {observables: 'embedded',weather_map_addresses: 'none', addresses: 'embedded', weather_map_domains: 'none', domains: 'embedded'}}
      end
      format.stix do
        stream = render_to_string(template: "searches/index.stix")

        if params[:profile].present? && params[:profile].downcase == 'isa'
          isa = Stix::Xslt::Transformer.new.transform_stix_xml(stream,'isa','USG',true)
          if isa.present?
            stream = isa
          else
            render json: {errors: "Could not transform XML to the ISA Profile"}
          end
        end

        send_data(stream, type: "text/xml", filename: "search_results_#{Time.now}.xml")
      end
      format.ais do
        stream = render_to_string(template: "searches/index.ais")

        if params[:profile].present? && params[:profile].downcase == 'isa'
          isa = Stix::Xslt::Transformer.new.transform_stix_xml(stream,'isa','USG',true)
          if isa.present?
            stream = isa
          else
            render json: {errors: "Could not transform XML to the ISA Profile"}
          end
        end

        send_data(stream, type: "text/xml", filename: "search_results_#{Time.now}.xml")
      end
    end

  end
end
