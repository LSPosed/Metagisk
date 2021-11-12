package com.topjohnwu.magisk.events.dialog

import android.view.LayoutInflater
import android.widget.TextView
import androidx.annotation.CallSuper
import androidx.lifecycle.lifecycleScope
import com.topjohnwu.magisk.R
import com.topjohnwu.magisk.core.base.BaseActivity
import com.topjohnwu.magisk.view.MagiskDialog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import timber.log.Timber
import kotlin.coroutines.cancellation.CancellationException

abstract class MarkDownDialog : DialogEvent() {

    abstract suspend fun getMarkdownText(): String

    @CallSuper
    override fun build(dialog: MagiskDialog) {
        with(dialog) {
            val view = LayoutInflater.from(context).inflate(R.layout.markdown_window_md2, null)
            applyView(view)
            (ownerActivity as BaseActivity).lifecycleScope.launch {
                val tv = view.findViewById<TextView>(R.id.md_txt)
                val text = withContext(Dispatchers.IO) {
                    try {
                        getMarkdownText()
                    } catch (e: Exception) {
                        if (e is CancellationException)
                            throw e
                        Timber.e(e)
                        tv.context.getString(R.string.download_file_error)
                    }
                }
                tv.text = text
            }
        }
    }
}
