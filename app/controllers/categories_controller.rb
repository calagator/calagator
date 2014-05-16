class CategoriesController < ApplicationController
  # GET /categories

  # GET /categories/1
  def show
    @category = Category.find(params[:id])
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # POST /categories
  def create
    @category = Category.new(params[:category])

    if @category.save
      redirect_to @category, notice: 'Category was successfully created.' 
    else
      render action: "new"
    end
  end

  # PUT /categories/1
  def update
    @category = Category.find(params[:id])

    if @category.update_attributes(params[:category])
      redirect_to @category, notice: 'Category was successfully updated.' 
    else
      render action: "edit"
    end
  end

  # DELETE /categories/1
  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    redirect_to categories_url
  end
end
