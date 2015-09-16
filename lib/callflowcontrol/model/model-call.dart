part of callflowcontrol.model;

/**
 * Local specialization of a [ORModel.Call] class.
 */
class Call extends ORModel.Call {

  void set assignedTo(int userID) {
    log.finest('Assigning $this to $userID');
    this._assignedTo = userID;
  }

  @override
  bool get locked              => this._locked;
  @override
  void set locked (bool lock)   {
    this._locked = lock;

    if (lock) {
      Notification.broadcastEvent(new OREvent.CallLock(this));
    }else {
      Notification.broadcastEvent(new OREvent.CallUnlock(this));
    }
  }

  Call(String ID) : super.empty(ID);

  @override
  void release() {
    log.finest('Releasing call assigned to: ${this.assignedTo}');

    if (this.assignedTo != ORModel.User.noID) {
      UserStatusList.instance.update(this.assignedTo, ORModel.UserState.WrappingUp);
    }

    this.assignedTo = ORModel.User.noID;
  }

  void link (Call other) {
    this.locked = false;

    this.bLeg  = other.ID;
    other.bLeg = this.ID;
  }

   @override
  String toString () => this.ID;

   Future park (ORModel.User user) {
     return Controller.PBX.park (this, user);
   }

  void changeState (String newState) {

    final String lastState = this.state;
    super.changeState(newState);

    log.finest('UUID: ${this.ID}: uid:${this.assignedTo} ${lastState} => ${newState}');

    if (lastState == CallState.Queued) {
      Notification.broadcastEvent(new OREvent.QueueLeave(this));
    } else if (lastState == CallState.Parked) {
      Notification.broadcastEvent(new OREvent.CallUnpark (this));
    }

    switch (newState) {
      case (CallState.Created):
        Notification.broadcastEvent(new OREvent.CallOffer (this));
        break;

      case (CallState.Parked):
        Notification.broadcastEvent(new OREvent.CallPark (this));
        break;

      case (CallState.Unparked):
        Notification.broadcastEvent(new OREvent.CallUnpark (this));
        break;

      case (CallState.Queued):
        Notification.broadcastEvent(new OREvent.QueueJoin (this));
        break;

      case (CallState.Hungup):
          Notification.broadcastEvent(new OREvent.CallHangup (this));
        break;

      case (CallState.Speaking):
        Notification.broadcastEvent(new OREvent.CallPickup (this));
        break;

      case (CallState.Transferred):
        Notification.broadcastEvent(new OREvent.CallTransfer (this));
        break;

      case  (CallState.Ringing):
        Notification.broadcastEvent(new OREvent.CallStateChanged (this));
        break;

      case (CallState.Transferring):
         break;

      default:
        log.severe('Changing call ${this} to Unkown state!');
      break;

    }
  }
}