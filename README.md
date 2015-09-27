# dirty-bomb-card-simulator
A script used to calculate costs &amp; probabilities for getting cards for the F2P game Dirty Bomb.

Here are some representative results:
```
$ perl dirt-bomb.pl
total_cost: 257558500
total_fusions: 82553
total_cases: 172257
total_trials: 1000
total_failures: 0
Average trials: 1
Average fusions: 82.553
Average cost: 257558.5
Average cases: 172.257
```

So it will take an average of 172 cases before you have enough material to buy a cobalt. The total cost will be 257558, of which 172000 is spent on cases and 85557 is spent on fusions.
