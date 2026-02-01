defmodule SpazioSolazzo.BookingSystem.SpaceTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  describe "create_space/5" do
    test "creates a space with all attributes" do
      assert {:ok, space} =
               BookingSystem.create_space(
                 "Test Space",
                 "test-space",
                 "test description",
                 10,
                 12
               )

      assert space.name == "Test Space"
      assert space.slug == "test-space"
      assert space.description == "test description"
      assert space.public_capacity == 10
      assert space.real_capacity == 12
    end

    test "requires public_capacity to be less than or equal to real_capacity" do
      assert {:error, error} =
               BookingSystem.create_space(
                 "Invalid Space",
                 "invalid",
                 "description",
                 15,
                 10
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be less than or equal to real_capacity")
    end

    test "allows public_capacity to equal real_capacity" do
      assert {:ok, space} =
               BookingSystem.create_space(
                 "Equal Space",
                 "equal",
                 "description",
                 10,
                 10
               )

      assert space.public_capacity == 10
      assert space.real_capacity == 10
    end

    test "requires positive capacity values" do
      assert {:error, error} =
               BookingSystem.create_space(
                 "Zero Space",
                 "zero",
                 "description",
                 -1,
                 5
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be greater than 0")
    end
  end

  describe "get_space_by_slug/1" do
    test "retrieves space by slug" do
      {:ok, _} =
        BookingSystem.create_space("Space", "test-slug", "test description", 5, 5)

      assert {:ok, space} = BookingSystem.get_space_by_slug("test-slug")

      assert space.slug == "test-slug"
      assert space.name == "Space"
    end

    test "returns error when space not found" do
      assert {:error, _} = BookingSystem.get_space_by_slug("nonexistent")
    end
  end

  describe "space uniqueness" do
    test "can't create two spaces with same slug" do
      assert {:ok, _} =
               BookingSystem.create_space("Space 1", "same-slug", "description 1", 5, 5)

      assert {:error, error} =
               BookingSystem.create_space("Space 2", "same-slug", "description 2", 10, 10)

      error_messages = Ash.Error.error_descriptions(error)

      assert String.contains?(error_messages, "has already been")
    end

    test "can't create two spaces with same name" do
      assert {:ok, _} =
               BookingSystem.create_space("Same Name", "slug-1", "description 1", 5, 5)

      assert {:error, error} =
               BookingSystem.create_space("Same Name", "slug-2", "description 2", 10, 10)

      error_messages = Ash.Error.error_descriptions(error)

      assert String.contains?(error_messages, "has already been")
    end

    test "can create spaces with different names and slugs" do
      assert {:ok, space1} =
               BookingSystem.create_space("Space 1", "slug-1", "description 1", 5, 5)

      assert {:ok, space2} =
               BookingSystem.create_space("Space 2", "slug-2", "description 2", 10, 10)

      assert space1.id != space2.id
    end
  end
end
