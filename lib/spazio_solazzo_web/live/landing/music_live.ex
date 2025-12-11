defmodule SpazioSolazzoWeb.MusicLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  import SpazioSolazzoWeb.LandingComponents

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("music")
    {:ok, asset} = BookingSystem.get_asset_by_space_id(space.id)

    images = [
      "https://lh3.googleusercontent.com/aida-public/AB6AXuD1wkxK48dk7i5XYX6JL-O1egrsdLjcmOg7N4EB76QtUvhzR7lZQadprIT9rLPsroUjazftFRpp_z26wb8lHaUW9XyucGlKG3qG40oT5iaKWwqVI1drNKJDJgVBkmNjw4u_D5vig_C1pf6bgGZnPaOV2tnnmlexxHJIDQYZzfg1GGwgywBvpGLz_u2_jvkbyMo3_m5roM09PjonFEfGIHxjm0vClW1DAOX45IrT87A85OdAXEu2EPyB8oW9WzmolOn4DFj22vKWSbVD",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuB3fJu4mgZaw8GP1OC2SjquJZJmnRlY_OHD4fO4AAd_KHd5BYnW1i0egrskoEfK_uCdK4pQu5kMf8pF9h_KXE0wYQAROnTBTJ4YmBpHui9nv8wz44VENo2p-lA3rW8xhQhiYzlAhHJlhgOdZluVp9eYvsZxGM76QkDXMcBQz1Ka5ZfRMNgddo1RS76IPaxbQIvpOh_55uW87bAiGAvhcE8GrIi2ugpiJ64Rdou1uZLD1bPWxUvyLtpTFFLr2vfVjq7OpVYiGnLaGstS",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBVY6j_kvSUC0trHVnwvszpxZa58CpY0sGTF6m6lPQJkFlN-GnK1ofNaSn8PU1JnmPPAl7B196LoYq4SfawlDFrg2ADKKr65cOE0jq2L9w-cXrkPxE4poylrIeKX8zP1JsIS5obvU5_HAG074RjeYSWFsV5Z7wQF0ktZlYL6m462hsl-xdLQWQiBLZOHNsBf6jrZieUst9dKUlec6hzWOqcbIXuugBJW5fklJmMti9CDQynn1XZ5I5gZYEL47tW2Ku9u_zEEpfqmEKF"
    ]

    {:ok,
     socket
     |> assign(
       space: space,
       asset: asset,
       images: images
     )}
  end
end
