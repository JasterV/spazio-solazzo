defmodule SpazioSolazzoWeb.CoworkingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  import SpazioSolazzoWeb.LandingComponents

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("coworking")
    {:ok, assets} = BookingSystem.get_space_assets(space.id)

    images = [
      "https://lh3.googleusercontent.com/aida-public/AB6AXuDmh_AkVuUoICqpHk1NdLuLdi0xQBOC8Hy9PrsSNz956igHFRhbNGsB8k0vSLe2U2NW1sxRVZm_dwR27Q4Db_f21XbYkLtfiRYob-j4ran1rTBB0bQAz4QLFSO1yL_cPhDIpAyvC069mDQ33-ckZgZ_yvFsIK_-_0Jj2NEOnDie684uaR7vKuiBWlsr-JmAsPzUp7Aik7Qbzozune348nBz1bvWkBNMCpMO3JV8hrYBo1i6JlUiGSuP3-5fWXKt8dKhxPUN-amjLFgh",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCh5O9cz1ruQFH0Pq3MzC_1HsWrLPHbWlfYEdB2dmPi0YDn2L23R5hseUZmb19XlEju1n4a24oD6pH5qiG4SvIemrD45PfKwvNlckpOG59IYz5WYrHzroq7L4Uq9Hxl0PTzU5m8R5k625w_MrdZKidyfM6OnzNJfM5J3XftFI5A9J7wD_BDHRKxq8gxAukUCesuYX8lGm3AhQAZQTjaUY5yeobjt-NCSrlfTzxmcUmibJSTnKZuwx-li4QtFr0wQrzHVLUZYiAhA251",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCanfiWzXqH3fBrE6U3phirIFZo5bgKG1aa8wnXCRC12yOXkcgnGUTRhxppIk61QUdQWF9KuFAtjhDEI9AACV-pM7yXyPKbOKognCARD-qbffFtCwGLidcLkoprLnNAW12C7TeRL6gOEBas3RI7jCf30JmzMmSqCjMx3lixgrOr6qlpbHZA4Eog_P41y5zXtn9Nqlq2eB6c7RYhiOIJzXVpMmfLR_qf0HTmOnx2poDbqKcLDcCM-p4S6aAwLxC-GYBmvEfWQ4meToCL"
    ]

    {:ok,
     socket
     |> assign(
       space: space,
       assets: assets,
       images: images
     )}
  end
end
