import logging


LOGGING_LEVELS = {
    "DEBUG": logging.DEBUG,
    "INFO": logging.INFO,
    "WARNING": logging.WARNING,
    "ERROR": logging.ERROR,
    "CRITICAL": logging.CRITICAL
}

def setup_logger(logger_name, out_name, level, verbose=False, mode="w"):
    """
    Convenience function which returns a logger object with a 
    specified name and level of reporting.
    Parameters
    ----------
    logger_name : str
        Name of the logger
    out_name : str
        Desired path for the logfile
    level : str (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        Desired level of reporting for the log. See Python's logging 
        documentation for more info.
    verbose : bool, default=False
        If True, information will also be sent to the terminal via a
        StreamHandler as well as to a log file.
    mode : str, default="w"
        The mode of operation for the FileHandler. The default mode, 
        "w", overwrites a logfile of the same name if it exists.
    """
    # set up logger's base reporting level and formatting
    logger = logging.getLogger(logger_name)
    logger.setLevel(LOGGING_LEVELS[level])
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    
    # set up FileHandler
    fh = logging.FileHandler(out_name, mode=mode)
    handlers = [fh, ]
    
    # set up StreamHandler (if verbose)
    if verbose:
        sh = logging.StreamHandler()
        handlers.append(sh)
    
    # add formatting to handlers and add to logger
    for handler in handlers:
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    
    return logger