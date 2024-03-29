class Post < Dynomite::Item
  fields :title, :desc
  def generate_random_key_schema_value(*); Digest::SHA1.hexdigest([Time.now, rand].join) ; end
end
class Comment < Dynomite::Item
  # partition_key :post_id # defaults to :id
  # sort_key :timestamp
  def generate_random_key_schema_value(*); Digest::SHA1.hexdigest([Time.now, rand].join) ; end
end
module Ns
  class Pet < Dynomite::Item
    def generate_random_key_schema_value(*); Digest::SHA1.hexdigest([Time.now, rand].join) ; end
  end
end

describe Dynomite::Item do
  before(:each) do
    # allow(Post).to receive(:desc_table).and_return(double(:table, attribute_definitions: []))
    allow(Post).to receive(:partition_key).and_return(:id)
    allow(Post).to receive(:sort_key).and_return(nil)
    allow(Comment).to receive(:partition_key).and_return(:post_id)
    allow(Comment).to receive(:sort_key).and_return(:timestamp)
  end

  describe "general" do
    it "loads attributes" do
      post = Post.new(title: "my title", desc: "my desc")
      expect(post.attrs).to eq("title" => "my title", "desc" => "my desc")

      post.title = "my title2"
      expect(post.attrs).to eq("title" => "my title2", "desc" => "my desc")
    end

    it "table_name" do
      expect(Post.table_name).to eq "dynomite_posts"
      expect(Comment.table_name).to eq "dynomite_comments"
      expect(Ns::Pet.table_name).to eq "dynomite_ns_pets"
    end

    it "partition_key" do
      expect(Post.partition_key).to eq :id
      expect(Comment.partition_key).to eq :post_id
    end

    it "sort_key" do
      expect(Post.sort_key).to be_nil
      expect(Comment.sort_key).to eq :timestamp
    end

    it "uses defined column" do
      post = Post.new
      expect(post.title).to be_nil
      expect(post.attrs).to_not include('title')

      post.title = 'abc'
      expect(post.title).to eq 'abc'
      expect(post.attrs).to include('title')
    end

    it "tries to use undefined column" do
      post = Post.new
      expect do
        post.undefined_column
      end.to raise_exception(NoMethodError)

      post.attrs = {'undefined_column' => 'value'}

      # getter method uses attrs also
      expect(post.undefined_column).to eq 'value'

      Post.add_field(:undefined_column)

      expect do
        post.undefined_column
      end.to_not raise_exception
    end
  end

  describe "CRUD-ish" do
    before(:each) { allow(Post).to receive(:client).and_return(client) }
    let(:client) { double(:client) }

    let(:find_resp) do
      fake_attributes = {"id" => "myid", "title" => "my title"}
      resp = double(:resp)
      expect(resp).to receive(:item).and_return(fake_attributes)
      resp
    end
    it "find" do
      expect(Post.client).to receive(:get_item).and_return(find_resp)

      post = Post.find("myid")

      expect(post.attrs.to_h).to eq(ActiveSupport::HashWithIndifferentAccess.new("id" => "myid", "title" => "my title"))
    end

    it "find with hash" do
      expect(Post.client).to receive(:get_item).and_return(find_resp)

      post = Post.find(id: "myid")

      expect(post.attrs).to eq("id" => "myid", "title" => "my title")
    end

    it "replace" do
      # Not returning a resp with receive because it is not useful
      # Dynanmodb doesnt provide much useful info there.
      allow(Dynomite::Item::Query::Write::Save).to receive(:call)

      post = Post.new(title: "my title")
      post.save
      attrs = post.attrs

      expect(attrs[:title]).to eq "my title"
      expect(attrs[:id].size).to eq 21 # IE: post-SSwsXtJ8KRocnxv5
    end

    it "replace with hash" do
      # Not returning a resp with receive because it is not useful
      # Dynamodb doesnt provide much useful info there.
      allow(Dynomite::Item::Query::Write::Save).to receive(:call)

      post = Post.new(title: "my title")
      post.attributes = {title: "my title 2"}
      post.save
      attrs = post.attributes

      expect(attrs[:title]).to eq "my title 2"
      expect(attrs[:id].size).to eq 21 # IE: post-SSwsXtJ8KRocnxv5
    end

    it "delete" do
      allow(Post.client).to receive(:delete_item)

      Post.delete("myid")

      expect(Post.client).to have_received(:delete_item)
    end

    it "delete_attribute" do
      allow(Dynomite::Item::Query::Write::Save).to receive(:call)

      post = Post.new(title: "my title", extras: "anything you want")
      post.save
      expect(post.attrs[:extras]).to eq "anything you want"
      post.delete_attribute(:extras)
      expect(post.attrs.keys).to_not include('extras')
    end

    let(:scan_resp) do
      fake_attributes = [{"id" => "myid", "title" => "my title"}]
      resp = double(:resp)
      expect(resp).to receive(:items).and_return(fake_attributes)
      resp
    end
    it "scan" do
      allow(Post.client).to receive(:scan).and_return(scan_resp)

      Post.scan

      expect(Post.client).to have_received(:scan)
    end

    it "count" do
      allow(Post).to receive(:scan_count).and_return(1)
      expect(Post.count).to eq 1
    end

    it "reload" do
      fake_attributes = {"id" => "myid", "title" => "my title"}
      post_resp = double(:resp)
      expect(post_resp).to receive(:item).and_return(fake_attributes).twice
      expect(Post.client).to receive(:get_item).and_return(post_resp).twice

      post = Post.find(id: "myid")
      post.reload

      expect(post.attrs).to eq("id" => "myid", "title" => "my title")
    end

    it "reload with sort key" do
      fake_attributes = {"post_id" => "myid", "title" => "my title", "timestamp" => 12345}
      comment_resp = double(:resp)
      expect(comment_resp).to receive(:item).and_return(fake_attributes).twice

      # expect(Comment.client).to receive(:get_item).
      #   with(table_name: 'dynomite_comments', key: { post_id: "myid", timestamp: 12345 }).
      #   and_return(comment_resp).twice
      # needed to add extra {} for .with() to work for ruby 3.2
      # related: https://github.com/rspec/rspec-mocks/issues/1512

      expect(Comment.client).to receive(:get_item).
        with({table_name: 'dynomite_comments', key: { post_id: "myid", timestamp: 12345 }}).
        and_return(comment_resp).twice

      comment = Comment.find(post_id: "myid", timestamp: 12345)
      comment.reload

      expect(comment.attrs).to eq("post_id" => "myid", "title" => "my title", "timestamp" => 12345)
    end
  end

  describe "validations" do
    class ValidatedItem < Dynomite::Item
      columns :field1, :field2, :id
      validates :field1, presence: true
      def generate_random_key_schema_value(*); Digest::SHA1.hexdigest([Time.now, rand].join) ; end
      def set_sort_key
        # mock out to avoid sort_key discovery
      end
    end

    before(:each) do
      allow(ValidatedItem).to receive(:client).and_return(client)
      allow(ValidatedItem).to receive(:partition_key).and_return(:id)
    end
    let(:client) { double(:client) }

    it "validates field1 column" do
      item = ValidatedItem.new
      expect(item.valid?).to be false
      expect(item.errors.messages).to include(:field1)
      expect(item.errors.messages[:field1].size).to eq 1
      expect(item.errors.messages[:field1][0]).to eq "can't be blank"

      item.field1 = 'content'
      expect(item.valid?).to be true
      expect(item.errors.messages).to be_empty
    end

    it "ignores field2 column" do
      item = ValidatedItem.new
      expect(item.respond_to?(:field2)).to be true

      item.valid? # runs validations

      expect(item.errors.messages).to_not include(:field2)
    end

    it "validates on save" do
      item = ValidatedItem.new
      expect(item.save).to be_a(ValidatedItem)
      expect(item.new_record).to be true # not saved successfully
      expect(item.valid?).to be false
      expect(item.errors.messages).to include(:field1)

      allow(Dynomite::Item::Query::Write::Save).to receive(:call)

      item.field1 = 'content'
      expect(item.save).to_not be_a(ValidatedItem)
      expect(item.valid?).to be true
      expect(item.errors.messages.size).to eq 0
    end

    it "validates on save!" do
      allow(Dynomite::Item::Query::Write::Save).to receive(:call)
      item = ValidatedItem.new
      expect { item.save! }.to raise_error(Dynomite::Error::Validation)
      expect(item.errors.messages).to include(:field1)

      allow(Dynomite::Item::Query::Write::Save).to receive(:call).and_return(true)
      item.field1 = 'content'
      expect{ item.save! }.to_not raise_error
      expect(item.errors.messages.size).to eq 0
    end
  end
end
