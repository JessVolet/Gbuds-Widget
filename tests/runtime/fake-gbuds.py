#!/usr/bin/python3
import json, sys, time
args=sys.argv[1:]
command=next((v for v in args if v in ['connect','disconnect','capabilities','watch','find','anc']),None)
def emit(value):
    print(json.dumps(value),flush=True)
if command=='capabilities':
    supported={'device_support':'supported','gbuds_support':'implemented'}
    unknown={'device_support':'unknown','gbuds_support':'unknown'}
    emit({'success':True,'device':{'name':'Test Buds3','model_code':'SM-R530'},'capabilities':{'noise_control_modes':['off','on','ambient'],'features':{'anc':supported,'ambient_sound':{'device_support':'unsupported','gbuds_support':'rejected'},'find_earbuds':unknown}}})
elif command=='watch':
    while True:
        emit({'left':94,'right':92,'case':59,'placement_left':'IDLE','placement_right':'WEARING','noise_control':'OFF'})
        time.sleep(.25)
elif command=='find':
    emit({'success':True,'find_target':args[-1]})
elif command in ['connect','disconnect']:
    emit({'success':True,command+'ed':True})
else:
    emit({'success':False,'error':'Unexpected fixture command: '+str(args)})
    sys.exit(1)
