#!/bin/sh
################################################################################
#
# PROGRAM:          environment.t
#
# PARAMETERS:       None
#
# RETURNS:          0 - Success
#                   1 - Failure
#
# USAGE:            ./environment.t
#
#                   or
#
#                   prove -v environment.t
#
# DESCRIPTION:      This program executes automated unit tests to determine
#                     the status of the DB2 environment.
#
################################################################################


################################################################################
# Variables
################################################################################
SUCCESS=0
FAILURE=1

DB2DB=$(echo "$DB2INSTANCE")
TMS="eval date +'%d-%m-%y %H:%M:%S'"
TMS_EXT=$(date +'%y%m%d%H%M%S')
SCRIPT=${0##*/}
SCR=$(echo ${SCRIPT} | cut -d . -f1)
PID=$$

#SQL files
invalid_pkgs_sql_file=$PWD/sql/qy_invalid_pkgs.sql
check_pending_tabs_sql_file=$PWD/sql/qy_check_pending_tabs.sql
reorg_tab_sql_file=$PWD/sql/qy_reorg_pending_tabs.sql
check_tablespace_sql_file=$PWD/sql/qy_check_tablespace_status.sql
invalid_procfuncs_sql_file=$PWD/sql/qy_invalid_procfuncs.sql

#Output files
invalid_pkgs_output_file=/tmp/rebind-$PID.sql
check_pending_tabs_output_file=/tmp/set-tab-integrity-$PID.sql
reorg_tab_output_file=/tmp/reorg-$PID.txt
check_tablespace_output_file=/tmp/tablespace_status-$PID.txt
invalid_procfuncs_output_file=/tmp/revalidate-$PID.sql

#DB2 CLP Exit Codes
DB2CLP_SQL_SUCCESS=0
DB2CLP_SQL_NO_ROWS=1
DB2CLP_SQL_WARNING=2
DB2CLP_SQL_ERROR=4
DB2CLP_ERROR=8

#############################################################################
# Function:    DBConnect
# Description: Connects to DB2
#############################################################################
DBConnect()
{
  db2 +o "CONNECT TO $DB2DB"
}

#############################################################################
# Function:    InvalidPackages
# Description: Check for Invalid Packages
#############################################################################
InvalidPackages()
{

  output=$(db2 -txf $invalid_pkgs_sql_file)
  exit_code=$?

  if [ $exit_code -eq $DB2CLP_SQL_NO_ROWS ]; then

      return $SUCCESS

  else

      echo "$output" > $invalid_pkgs_output_file

      return $FAILURE

  fi;
}

#############################################################################
# Function:    CheckPendingTabs
# Description:
#############################################################################
CheckPendingTabs()
{

  output=$(db2 -txf $check_pending_tabs_sql_file)

  exit_code=$?

  if [ $exit_code -eq $DB2CLP_SQL_NO_ROWS ]; then

    return $SUCCESS

  else

    echo "$output" > $check_pending_tabs_output_file

    return $FAILURE

  fi
}

#############################################################################
# Function:    ReorgPendingTabs
# Description:
#############################################################################
ReorgPendingTabs()
{

  output=$(db2 -tf $reorg_tab_sql_file)

  exit_code=$?

  if [ $exit_code -eq $DB2CLP_SQL_NO_ROWS ]; then

    return $SUCCESS

  else

    echo "$output" > $reorg_tab_output_file

    return $FAILURE

  fi
}

#############################################################################
# Function:    CheckTableSpaceStatus
# Description:
#############################################################################
CheckTableSpaceStatus()
{

  output=$(db2 -tf $check_tablespace_sql_file)

  exit_code=$?

  if [ $exit_code -eq $DB2CLP_SQL_NO_ROWS ]; then

    return $SUCCESS

  else

    echo "$output" > $check_tablespace_output_file

    return $FAILURE

  fi

}

#############################################################################
# Function:    InvalidProcsFuncs
# Description:
#############################################################################
InvalidProcsFuncs()
{

  output=$(db2 -txf $invalid_procfuncs_sql_file)

  exit_code=$?

  if [ $exit_code -eq $DB2CLP_SQL_NO_ROWS ]; then

    return $SUCCESS

  else

    echo "$output" > $invalid_procfuncs_output_file

    return $FAILURE

  fi

}

################################################################################
# Main (EDIT THIS SECTION)
#
################################################################################

test_description="Test that the environment is ready for a Release"

. ./bin/sharness.sh

DBConnect


## pre-req of DB connection
db2 "values current server" >/dev/null && test_set_prereq DBCONNECTION

################################################################################
# Start Unit Tests (EDIT THIS SECTION)
################################################################################

# Check for Invalid Database Packages
test_expect_success DBCONNECTION "Database Packages Valid" "
  InvalidPackages
  # If test not OK re-bind invalid packages:
  #   db2 -tvf $invalid_pkgs_output_file
"

# Check for Tables in Check-Pending state
test_expect_success DBCONNECTION "Tables Not Check Pending" "
  CheckPendingTabs
  # If test not OK re-check tables:
  #   db2 -tvf $check_pending_tabs_output_file
"

## check for Tables REORG pending
test_expect_success DBCONNECTION "Tables Not REORG Pending" "
  ReorgPendingTabs
  # If test not OK tables see tables found in REORG pending state:
  #   cat $reorg_tab_output_file
"

## check for Invalid Tablespaces
test_expect_success DBCONNECTION "Tablespaces in NORMAL state" "
  CheckTableSpaceStatus
  # If test not OK tables see tablespaces found in NOT NORMAL state:
  #   cat $check_tablespace_output_file
"

## Check for Invalid Database Procedures and Functions
test_expect_success DBCONNECTION "Database Procedures and Functions Valid" "
  InvalidProcsFuncs
  # If test not OK re-validate invalid procedures and functions:
  #   db2 -tvf $invalid_procfuncs_output_file
"

## End test - must be present do not modify
test_done

