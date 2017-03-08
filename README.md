# db2-check-state

Various DB2 database state checks wrapped in a test harness for repeatability and automation.

## Tests

Tests are SQL statements executed via a [Sharness](http://chriscool.github.io/sharness/) test harness. The output is [TAP](http://testanything.org/) compatible so can be consumed by many [systems](http://testanything.org/consumers.html).

Test currently included are:

1. [Invalid Packages](sql/qy_check_pending_tabs.sql)
2. [Tablespace Status](sql/qy_check_tablespace_status.sql)
3. [Invalid Packages](sql/qy_invalid_pkgs.sql)
4. [Invalid Procedures and Functions](sql/qy_invalid_procfuncs.sql)
5. [Re-Org Pending Tables](sql/qy_reorg_pending_tabs.sql)

If tests fail re-mediation scripts are generated (to rebind packages for example).


## Usage

- Clone this repo:

```git clone https://github.com/jonbartlett/db2-check-state.git```
- There is no uniform method to get the database instance name therefore editing the function ```DBConnect()``` may be necessary.
- Run tests either directly:

```
$ ./environment.t
```

or via [Prove](https://linux.die.net/man/1/prove):

```
$ prove -v environment.t
```

![demo screen cast](demo.gif)

## Contributions

Are welcome. Fork and submit pull request.


