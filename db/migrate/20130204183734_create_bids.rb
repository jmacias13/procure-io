class CreateBids < ActiveRecord::Migration
  def change
    create_table :bids do |t|
      t.integer :vendor_id
      t.integer :project_id

      t.timestamps
    end
  end
end
