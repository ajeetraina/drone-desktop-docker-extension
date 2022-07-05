import {
  Backdrop,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  Typography
} from '@mui/material';
import React from 'react';
import { useAppDispatch } from '../app/hooks';
import RemoveCircleIcon from '@mui/icons-material/RemoveCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import { getDockerDesktopClient } from '../utils';

export default function RemovePipelineDialog({ ...props }) {
  const dispatch = useAppDispatch();
  const [actionInProgress, setActionInProgress] = React.useState<boolean>(false);

  const ddClient = getDockerDesktopClient();

  const handleDeletePipeline = async () => {
    setActionInProgress(true);
    let response;
    try {
      const pipelineIds = props.selectedToRemove;
      //console.log('Removing pipelines ' + JSON.stringify(pipelineIds));
      response = await ddClient.extension.vm.service.post('/pipelines/delete', pipelineIds);
    } catch (err) {
      ddClient.desktopUI.toast.error(`Error removing pipelines ${err?.message}`);
    } finally {
      setActionInProgress(false);
      props.onClose(response);
    }
  };

  return (
    <Dialog
      open={props.open}
      onClose={props.onClose}
    >
      <DialogTitle>Remove pipelines ?</DialogTitle>
      <DialogContent>
        <Backdrop
          sx={{
            backgroundColor: 'rgba(245,244,244,0.4)',
            zIndex: (theme) => theme.zIndex.drawer + 1
          }}
          open={actionInProgress}
        >
          <CircularProgress color="info" />
        </Backdrop>

        <Grid
          container
          direction="column"
          spacing={2}
        >
          <Grid item>
            <Typography
              variant="body1"
              color="text.secondary"
              sx={{ mt: 2 }}
            >
              Are you sure of removing the pipeline(s)?
            </Typography>
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button
          variant="contained"
          onClick={() => {
            props.onClose();
          }}
          endIcon={<CancelIcon />}
        >
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleDeletePipeline}
          endIcon={<RemoveCircleIcon />}
        >
          Remove
        </Button>
      </DialogActions>
    </Dialog>
  );
}
