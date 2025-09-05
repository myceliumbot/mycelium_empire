import { useQuery } from '@tanstack/react-query'
import { leaderboard } from './api'

export function Leaderboard() {
  const { data, isLoading } = useQuery({ queryKey: ['leaderboard'], queryFn: leaderboard, refetchInterval: 5000 })
  if (isLoading) return <div>Loading...</div>
  return (
    <div style={{ marginTop: 24 }}>
      <h2>Top Colonies</h2>
      <ol>
        {data?.map((row) => (
          <li key={row.playerId}>
            {row.playerId.slice(0, 8)} — {row.score}
          </li>
        ))}
      </ol>
    </div>
  )
}

