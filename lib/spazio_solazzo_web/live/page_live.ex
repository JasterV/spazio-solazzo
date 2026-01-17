defmodule SpazioSolazzoWeb.PageLive do
  use SpazioSolazzoWeb, :live_view

  import SpazioSolazzoWeb.PageComponents
  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, coworking_space} = BookingSystem.get_space_by_slug("coworking", not_found_error?: false)
    {:ok, meeting_space} = BookingSystem.get_space_by_slug("meeting", not_found_error?: false)
    {:ok, music_space} = BookingSystem.get_space_by_slug("music", not_found_error?: false)

    carousel_images = [
      "https://lh3.googleusercontent.com/aida-public/AB6AXuApty1_MYrfkL2mpGOAKKvlxo-7B-Y6nnko3DA4UDhJ-dCSjcyOLMFy1C0xZmh1_Pu9TEEFj25GkJ74dR1Sb_x4sY9mDjecKICFvwHFgHkMFVMigsZjldl9rH34x4tZhdpWvUGCo32V1P5_0uwtXVPohKMbvIbBxr5nsPoEy_d7X4WgIMOA1Nv2bwDgkqbsG4X3noBx-riLqcnREEl3cb0kbtquJZJ6pYHfbimuNyuxtfQHzrG8KOMHe3YPoIgWt43mgPtgPL9gswni",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuDmh_AkVuUoICqpHk1NdLuLdi0xQBOC8Hy9PrsSNz956igHFRhbNGsB8k0vSLe2U2NW1sxRVZm_dwR27Q4Db_f21XbYkLtfiRYob-j4ran1rTBB0bQAz4QLFSO1yL_cPhDIpAyvC069mDQ33-ckZgZ_yvFsIK_-_0Jj2NEOnDie684uaR7vKuiBWlsr-JmAsPzUp7Aik7Qbzozune348nBz1bvWkBNMCpMO3JV8hrYBo1i6JlUiGSuP3-5fWXKt8dKhxPUN-amjLFgh",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBBJs1jEAgwwiIvJD00kx3aA9pfI-o2fXT-eZ9dEQeHNHhvwQdVqrwsqwNvCR69rIYUNBKf-uY1dqXZSvXaXoE__slTLMqGHkUzSQSXql9PwhW3cLoMMv1wtj52qDORHy-0NE2_qbTLxm051aTxGLloQKUCIklZ0EMKxs8lvMpnLisnRZBkSMyUVcTBcQu16gZw3eDuMGUtXaTXskrQFGwDcThTCCF4TZiNAmgEk87ae3VgEwfJ2zBVeyHQ-BfMo5KHRtNl6lbzBT9N"
    ]

    {:ok,
     assign(socket,
       coworking_space: coworking_space,
       meeting_space: meeting_space,
       music_space: music_space,
       carousel_images: carousel_images
     )}
  end
end
