class KillChainsController < ApplicationController

  def index
    @kill_chains = KillChain.all
    @kill_chains = KillChain.find_by_is_default(true) if params[:default].present?

    render json: @kill_chains
  end
  
end
