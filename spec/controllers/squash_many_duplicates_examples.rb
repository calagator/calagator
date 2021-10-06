# frozen_string_literal: true

shared_examples '#squash_many_duplicates' do |model|
  before do
    @master = create(model, title: 'master')
    @dup1 = create(model, title: 'dup1')
    @dup2 = create(model, title: 'dup2')
  end

  context 'happy path' do
    before do
      post :squash_many_duplicates, params: { master_id: @master.id, duplicate_id_1: @dup1.id, duplicate_id_2: @dup2.id }
    end

    it 'squashes the duplicates into the master' do
      expect(@master.duplicate_ids).to match_array([@dup1.id, @dup2.id])
    end

    it 'redirects to duplicates page for more duplicate squashing' do
      expect(response).to redirect_to("/#{model}s/duplicates")
    end

    it 'sets the flash success message' do
      expect(flash[:success]).to eq(%(Squashed duplicate #{model}s ["dup1", "dup2"] into master #{@master.id}.))
    end
  end

  context 'with no master' do
    it 'redirects with a failure message' do
      post :squash_many_duplicates, params: { duplicate_id_1: @dup1.id, duplicate_id_2: @dup2.id }
      expect(flash[:failure]).to eq("A master #{model} must be selected.")
      expect(response).to redirect_to("/#{model}s/duplicates")
    end
  end

  context 'with no duplicates' do
    it 'redirects with a failure message' do
      post :squash_many_duplicates, params: { master_id: @master.id }
      expect(flash[:failure]).to eq("At least one duplicate #{model} must be selected.")
      expect(response).to redirect_to("/#{model}s/duplicates")
    end
  end

  context 'with duplicates containing master' do
    it 'redirects with a failure message' do
      post :squash_many_duplicates, params: { master_id: @master.id, duplicate_id_1: @master.id }
      expect(flash[:failure]).to eq("The master #{model} could not be squashed into itself.")
      expect(response).to redirect_to("/#{model}s/duplicates")
    end
  end
end
