{ ... }:
{
  services.cashewnix = {
    enable = true;
    settings = {
      public_keys = [
        # just use one generic one for all hosts I don't give a shit
        "cashewnix:6I1s+6KTRFgSD/0kN/V2v0aUhtfQ7vHOYx3bq3PW1YQ="
      ];
    };
  };
}
