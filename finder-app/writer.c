#include <sys/types.h>
#include <sys/stat.h>
#include <sys/klog.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
	int fd;
	int n;

	openlog(argv[0], LOG_NDELAY, LOG_USER);

	if (argc != 3) {
		syslog(LOG_ERR, "Wrong number of arguments. Please try again.\n");
		closelog();
		return 1;
	}

	fd = open(argv[1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd == -1) {
		syslog(LOG_ERR, "Could not open the given file %s\n", argv[1]);
		syslog(LOG_ERR, "Got %s\n", strerror(errno));
		closelog();
		return 1;
	}

	syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);

	n = write(fd, argv[2], strlen(argv[2]));
	if (n == -1) {
		syslog(LOG_ERR, "Could not write %s to file %s\n", argv[2], argv[1]);
		closelog();
		return 1;
	}

	close(fd);

	return 0;
}
