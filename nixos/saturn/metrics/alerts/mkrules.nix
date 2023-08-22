{ lib }:
lib.mapAttrsToList
  (name: opts: {
    alert = name;
    expr = opts.condition;
    for = opts.time or "2m";
    labels = { };
    annotations.description = opts.description;
    # for matrix alert-receiver
    #annotations.summary = opts.description;
  })
