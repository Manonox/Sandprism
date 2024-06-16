if Script then
    Script.CLIENT = Script.isClient()
    Script.SERVER = Script.isServer()

    Script.OWNER = Script.getOwner()
    -- script.PLAYER = ?

    Script.LOCAL = Script.isClient() and Script.getOwnerId() == Script.getClientId()
    Script.REMOTE = Script.isClient() and Script.getOwnerId() ~= Script.getClientId()

    Script.isClient = nil -- ?
    Script.isServer = nil -- ?
end