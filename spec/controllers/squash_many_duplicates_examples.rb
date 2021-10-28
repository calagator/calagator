# frozen_string_literal: true

shared_examples '#squash_many_duplicates' do |model|
  before do
    @primary = create(model, title: 'primary')
    @dup1 = create(model, title: 'dup1')
    @dup2 = create(model, title: 'dup2')
  end

  context 'happy path' do
    before do
      post :squash_many_duplicates, params: { primary_id: @primary.id, duplicate_id_1: @dup1.id, duplicate_id_2: @dup2.id }
    end

    it 'squashes the duplicates into the primary' do
      expect(@primary.duplicate_ids).to match_array([@dup1.id, @dup2.id])
    end

    it 'redirects to duplicates page for more duplicate squashing' do
      expect(response).to redirect_to("/#{model}s/duplicates")
    end

    it 'sets the flash success message' do
      expect(flash[:success]).to eq(%(Squashed duplicate #{model}s ["dup1", "dup2"] into primary #{@primary.id}.))
    end
  end

  context 'with no primary' do
    it 'redirects with a failure message' do
      post :squash_many_duplicates, params: { duplicate_id_1: @dup1.id, duplicate_id_2: @dup2.id }
      expect(flash[:failure]).to eq("A primary #{model} must be selected.")
      expect(response).to redirect_to("/#{model}s/duplicates")
    end
  end

  context 'with no duplicates' do
    it 'redirects with a failure message' do
      post :squash_many_duplicates, params: { primary_id: @primary.id }
      expect(flash[:failure]).to eq("At least one duplicate #{model} must be selected.")
      expect(response).to redirect_to("/#{model}s/duplicates")
    end
  end

  context 'with duplicates containing primary' do
    it 'redirects with a failure message' do
      post :squash_many_duplicates, params: { primary_id: @primary.id, duplicate_id_1: @primary.id }
      expect(flash[:failure]).to eq("The primary #{model} could not be squashed into itself.")
      expect(response).to redirect_to("/#{model}s/duplicates")
    end
  end
end
