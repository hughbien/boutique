Sequel.migration do
  change do
    create_table(:subscribers) do
      primary_key :id
      column :list_key, String, null: false
      column :email, String, null: false
      column :secret, String, null: false
      column :confirmed, TrueClass, null: false, default: false
      column :created_at, DateTime, null: false
      column :drip_on, Date, null: false
      column :drip_day, Integer, null: false, default: 0
    end

    create_table(:emails) do
      primary_key :id
      foreign_key :subscriber_id, :subscribers
      column :email_key, String, null: false
      column :created_at, DateTime, null: false
    end
  end
end
