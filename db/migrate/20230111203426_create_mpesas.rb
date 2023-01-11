class CreateMpesas < ActiveRecord::Migration[7.0]
  def change
    create_table :mpesas do |t|

      t.timestamps
    end
  end
end
