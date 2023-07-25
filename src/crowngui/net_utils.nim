import net


proc findAvailablePort*(): int =
  let socket = newSocket()
  bindAddr(socket)
  let local = socket.getLocalAddr()
  close(socket)
  return local[1].int