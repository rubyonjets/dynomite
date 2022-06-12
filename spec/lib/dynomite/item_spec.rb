require "spec_helper"
require "active_model"

class Post < Dynomite::Item
  column :defined_column
end
class Comment < Dynomite::Item
  partition_key "post_id" # defaults to id
end
module Ns
  class Pet < Dynomite::Item; end
end

describe Dynomite::Item do
  describe "general" do
    it "loads attributes" do
      post = Post.new(title: "my title", desc: "my desc")
      expect(post.attrs).to eq("title" => "my title", "desc" => "my desc")

      post.attrs(title: "my title2")
      expect(post.attrs).to eq("title" => "my title2", "desc" => "my desc")
    end

    it "table_name" do
      expect(Post.table_name).to eq "testnamespace-posts"
      expect(Comment.table_name).to eq "testnamespace-comments"
      # hack to quickly test blank and namespaces
      old_namespace = Comment.instance_variable_get(:@table_namespace)
      Comment.instance_variable_set(:@table_namespace, '')
      expect(Comment.table_name).to eq "comments"
      Comment.instance_variable_set(:@table_namespace, old_namespace)
      # test for namespaced models
      expect(Ns::Pet.table_name).to eq "testnamespace-ns-pets"
    end

    it "partition_key" do
      expect(Post.partition_key).to eq "id"
      expect(Comment.partition_key).to eq "post_id"
    end

    it "uses defined column" do
      post = Post.new
      expect(post.defined_column).to be_nil
      expect(post.attrs).to_not include('defined_column')

      post.defined_column = 'abc'
      expect(post.defined_column).to eq 'abc'
      expect(post.attrs).to include('defined_column')
    end

    it "tries to use undefined column" do
      post = Post.new
      expect do
        post.undefined_column
      end.to raise_exception(NoMethodError)

      post.attrs('undefined_column' => 'value')

      # should not allow access while column is undefined
      expect do
        post.undefined_column
      end.to raise_exception(NoMethodError)

      Post.add_column('undefined_column')

      expect do
        post.undefined_column
      end.to_not raise_exception
    end
  end

  describe "CRUD-ish" do
    before(:each) { Post.db = db }
    let(:db) { double(:db) }

    let(:find_resp) do
      fake_attributes = {"id" => "myid", "title" => "my title"}
      resp = double(:resp)
      expect(resp).to receive(:item).and_return(fake_attributes)
      resp
    end
    it "find" do
      expect(Post.db).to receive(:get_item).and_return(find_resp)

      post = Post.find("myid")

      expect(post.attrs).to eq("id" => "myid", "title" => "my title")
    end

    it "find with hash" do
      expect(Post.db).to receive(:get_item).and_return(find_resp)

      post = Post.find(id: "myid")

      expect(post.attrs).to eq("id" => "myid", "title" => "my title")
    end

    it "replace" do
      # Not returning a resp with receive because it is not useful
      # Dynanmodb doesnt provide much useful info there.
      expect(Post.db).to receive(:put_item)

      post = Post.new(title: "my title")
      post.replace
      attrs = post.attrs

      expect(attrs[:title]).to eq "my title"
      expect(attrs[:id].size).to eq 40 # generated unique id
    end

    it "replace with hash" do
      # Not returning a resp with receive because it is not useful
      # Dynanmodb doesnt provide much useful info there.
      expect(Post.db).to receive(:put_item)

      post = Post.new(title: "my title")
      post.replace(title: "my title 2")
      attrs = post.attrs

      expect(attrs[:title]).to eq "my title 2"
      expect(attrs[:id].size).to eq 40 # generated unique id
    end

    it "delete" do
      allow(Post.db).to receive(:delete_item)

      Post.delete("myid")

      expect(Post.db).to have_received(:delete_item)
    end

    let(:scan_resp) do
      fake_attributes = [{"id" => "myid", "title" => "my title"}]
      resp = double(:resp)
      expect(resp).to receive(:items).and_return(fake_attributes)
      resp
    end
    it "scan" do
      allow(Post.db).to receive(:scan).and_return(scan_resp)

      post = Post.scan

      expect(Post.db).to have_received(:scan)
    end

    it "count" do
      table = double(:table)
      allow(Post).to receive(:table).and_return(table)
      expect(table).to receive(:item_count).and_return(1)

      expect(Post.count).to eq 1
    end
  end

  describe "querying" do
    before(:each) { Post.db = db }
    let(:db) { double(:db) }

    let!(:find_resp) do
      fake_attributes = [{"id" => "myid", "title" => "my title"}]
      resp = double(:resp)
      expect(resp).to receive(:items).and_return(fake_attributes)
      resp
    end
    let(:base_posts_query) do
      expect(Post.db).to receive(:query).and_return(find_resp)
      Post.index_name("category-index").where(category: "some category")
    end

    it "single where" do
      posts = base_posts_query
      expect(posts.to_a.first).to be_a(Post)
    end

    it "acts as enumerable" do
      post_ids = base_posts_query.map { |p| p.attrs[:id] }
      expect(post_ids).to eq(["myid"])
    end

    it "query object inspect" do
      expect(base_posts_query.inspect).to include("#<Dynomite::Query [#<Post")
    end

    it "chained where" do
      expect(Post.db).to receive(:query).with(
        expression_attribute_names: { "#category_name"=>:category },
        expression_attribute_values: { ":category_value"=>"some other category" },
        index_name: "category-index",
        key_condition_expression: "#category_name = :category_value",
        table_name: "testnamespace-posts"
      ).and_return(find_resp)
      posts = Post.index_name("category-index").where(category: "some category")
                  .where(category: "some other category")
      expect(posts.to_a.first).to be_a(Post)
    end
  end

  describe "validations" do
    class ValidatedItem < Dynomite::Item
      include ActiveModel::Validations

      column :first, :second
      validates :first, presence: true
    end

    before(:each) { ValidatedItem.db = db }
    let(:db) { double(:db) }

    it "validates first column" do
      post = ValidatedItem.new
      expect(post.valid?).to be false
      expect(post.errors.messages).to include(:first)
      expect(post.errors.messages[:first].size).to eq 1
      expect(post.errors.messages[:first][0]).to eq "can't be blank"

      post.first = 'content'
      expect(post.valid?).to be true
      expect(post.errors.messages).to be_empty
    end

    it "ignores second column" do
      post = ValidatedItem.new
      expect(post.respond_to?(:second)).to be true

      post.valid? # runs validations

      expect(post.errors.messages).to_not include(:second)
    end

    it "validates on replace" do
      post = ValidatedItem.new
      expect(post.replace).to be false
      expect(post.errors.messages).to include(:first)

      expect(ValidatedItem.db).to receive(:put_item)

      post.first = 'content'
      expect(post.replace).to_not be false
      expect(post.errors.messages.size).to eq 0
    end

    it "validates on replace!" do
      post = ValidatedItem.new
      expect { post.replace! }.to raise_error(Dynomite::Errors::ValidationError)
      expect(post.errors.messages).to include(:first)

      expect(ValidatedItem.db).to receive(:put_item)

      post.first = 'content'
      expect{ post.replace! }.to_not raise_error
      expect(post.errors.messages.size).to eq 0
    end
  end
end
