class ShoesController < ApplicationController
  def show
    @shoe = Shoe.find params[:id]
  end

  def index
    @shoes = Shoe.offset(params[:page].to_i - 1).limit(1)
  end
end
