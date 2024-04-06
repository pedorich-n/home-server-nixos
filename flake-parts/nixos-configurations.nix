{ importApply, withSystem, inputs, self }:
importApply ../machines { inherit withSystem inputs self; }
